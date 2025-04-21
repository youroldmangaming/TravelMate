.PHONY: build run clean update-passwords status logs

# Variables
IMAGE_NAME=rpi-travel-router
CONTAINER_NAME=travel-router

# Include environment variables from .env file
include .env
export $(shell sed 's/=.*//' .env)

# Build the Docker image
build:
	# Create all the necessary template files first
	bash -c "cat template-files | bash"  
	docker build -t $(IMAGE_NAME) .

# Run the container with necessary privileges and device access
run:
	# Create shared directory on host if it doesn't exist
	mkdir -p $(HOST_SHARED_DIR)
	
	docker run -d --name $(CONTAINER_NAME) \
		--restart unless-stopped \
		--privileged \
		--network host \
		--env-file .env \
		-v /dev:/dev \
		-v /lib/modules:/lib/modules:ro \
		-v /sys:/sys \
		-v $(HOST_SHARED_DIR):/shared \
		$(IMAGE_NAME)

# Update passwords if they've changed in .env
update-passwords:
	docker exec -it $(CONTAINER_NAME) pihole -a -p "${PIHOLE_PASSWORD}"
	docker exec -it $(CONTAINER_NAME) bash -c '(echo "${SMB_PASSWORD}"; echo "${SMB_PASSWORD}") | smbpasswd -a -s ${SMB_USERNAME}'
	docker exec -it $(CONTAINER_NAME) bash -c 'echo "${RASPAP_USERNAME}:$(htpasswd -nb ${RASPAP_USERNAME} ${RASPAP_PASSWORD} | cut -d ":" -f 2)" > /etc/raspap/raspap.users'

# Show status of all services
status:
	docker exec -it $(CONTAINER_NAME) supervisorctl status

# View logs
logs:
	docker logs $(CONTAINER_NAME)

# Clean up
clean:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	docker rmi $(IMAGE_NAME) || true
