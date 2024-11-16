#include <iostream>
#include <fstream>
#include <string>

int main() {
    std::ifstream inputFile("gps_data.txt");
    if (!inputFile) {
        std::cerr << "Error opening the file!" << std::endl;
        return 1;
    }

    std::string line, result;
    bool isEmptyLine = false;

    while (std::getline(inputFile, line)) {
        if (line.empty()) {
            // If it's an empty line, mark it as an empty line
            if (isEmptyLine) {
                // If it's consecutive empty lines, add a newline before starting new string
                result += '\n';
            }
            isEmptyLine = true;
        } else {
            // If it's not empty, append the character to the current line
            result += line;
            isEmptyLine = false;
        }
    }

    inputFile.close();
    
    // Print the result
    std::cout << result << std::endl;
    
    return 0;
}
