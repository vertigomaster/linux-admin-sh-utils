#!/bin/bash

# Default values
KING_USER="king"
FALLBACK_USER=$(whoami)
DEFAULT_PASSWORD="ChangeMe123!"
KING_PASSWORD=$DEFAULT_PASSWORD
DEFAULT_SHELL="/bin/zsh"

# Parse command line options
while getopts "k:f:p:s:" opt; do
    case ${opt} in
        k )
            KING_USER=$OPTARG
            ;;
        f )
            FALLBACK_USER=$OPTARG
            ;;
        p )
            KING_PASSWORD=$OPTARG
            ;;
        s )
            DEFAULT_SHELL=$OPTARG
            ;;
        \? )
            echo "Usage: cmd [-k king_user] [-f fallback_user] [-p king_password]"
            exit 1
            ;;
    esac
done

echo "Crowning a new king user '$KING_USER' with sudo privileges..."

# Create the 'king' user with a home directory (to share with fallback user)
sudo useradd -m -G sudo "$KING_USER" || { 
    echo "Encountered issue, user group likely exists. Adjusting accordingly...";
    sudo useradd -m -g sudo "$KING_USER" && echo "User '$KING_USER' created successfully!";
}

# Set password for 'king' (modify as needed)
echo "Setting password for $KING_USER..."
echo "$KING_USER:$KING_PASSWORD" | sudo chpasswd

if [ "$KING_PASSWORD" == "$DEFAULT_PASSWORD" ]; then
    echo -e "\e[31m ⚠️ Password for '$KING_USER' set to default: 'ChangeMe123!' (Please change it immediately!)\e[0m"
else
    echo "🔑 Password for '$KING_USER' set!"
fi

# Enable passwordless sudo for 'king'
echo "$KING_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null

# Share access to the fallback's home directory by adding 'king' to the fallback's group
FALLBACK_GROUP=$(id -gn "$FALLBACK_USER")
sudo usermod -aG "$FALLBACK_GROUP" "$KING_USER"

# Also add 'dude' to 'king's group to ensure mutual access 
# (as a new user, king will have its own group sharing the same name)
sudo usermod -aG "$KING_USER" "$FALLBACK_USER"

# Set correct permissions for shared access
sudo chmod -R 770 /home/"$FALLBACK_USER"
sudo chown -R "$FALLBACK_USER":"$FALLBACK_GROUP" /home/"$FALLBACK_USER"

# Remove 'king' default configs (to avoid conflicts)
echo "Removing default config files for '$KING_USER'..."
sudo rm -rf /home/"$KING_USER"/.bashrc /home/"$KING_USER"/.zshrc /home/"$KING_USER"/.vimrc /home/"$KING_USER"/.config

# Create symlinks to share 'dude's configurations
echo "Creating symlinks for '$KING_USER'..."
sudo ln -s /home/"$FALLBACK_USER"/.bashrc /home/"$KING_USER"/.bashrc
sudo ln -s /home/"$FALLBACK_USER"/.zshrc /home/"$KING_USER"/.zshrc
sudo ln -s /home/"$FALLBACK_USER"/.vimrc /home/"$KING_USER"/.vimrc
sudo ln -s /home/"$FALLBACK_USER"/.config /home/"$KING_USER"/.config
sudo ln -s /home/"$FALLBACK_USER"/.oh-my-zsh /home/"$KING_USER"/.oh-my-zsh

# Set proper umask to prevent permission issues
echo "Setting global umask..."
echo "umask 0002" | sudo tee -a /etc/profile > /dev/null

echo "updating $KING_USER's default shell to '$DEFAULT_SHELL'"
su -c "chsh -s \"$DEFAULT_SHELL\" \"$KING_USER\"" king

echo "✅ Setup complete! You can now log in as '$KING_USER' and access everything as '$FALLBACK_USER'."




