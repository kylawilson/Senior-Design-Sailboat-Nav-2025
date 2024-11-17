#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>

void processGGA(const std::string& line) {
    std::stringstream ss(line);
    std::string token;
    std::vector<std::string> fields;

    // Split the line into fields based on commas
    while (std::getline(ss, token, ',')) {
        fields.push_back(token);
    }

    // Ensure the line contains at least the required number of fields
    if (fields.size() >= 10) {
        std::string UTCtime = fields[1];
	if (fields[2] != "" && fields[3] != "" && fields[4] != "" && fields[5] != "" && fields[9] != ""){
	        std::string Latitude = fields[2];
	std::string latIndicator = fields[3];
        std::string Longitude = fields[4];
        std::string longIndicator = fields[5];
        std::string Altitude = fields[9]; // Value before the first 'M'
	}
    }	

        // Print or use the extracted values
        std::cout << "GGA Data:" << std::endl;
        std::cout << "  UTCtime: " << UTCtime << std::endl;
       if (Latitude != "" && latIndicator != "" && Longitude != "" &&  longIndicator != ""){
	std::cout << "  Latitude: " << Latitude << std::endl;
        std::cout << "  latIndicator: " << latIndicator << std::endl;
        std::cout << "  Longitude: " << Longitude << std::endl;
        std::cout << "  longIndicator: " << longIndicator << std::endl;
        std::cout << "  Altitude: " << Altitude << std::endl;
    	}
    } else {
        std::cerr << "Invalid GGA line: " << line << std::endl;
    }
}

void processRMC(const std::string& line) {
    std::stringstream ss(line);
    std::string token;
    std::vector<std::string> fields;

    // Split the line into fields based on commas
    while (std::getline(ss, token, ',')) {
        fields.push_back(token);
    }

    // Ensure the line contains at least the required number of fields
    if (fields.size() >= 9) {
	if ((fields[7] != "" || fields[7] != "0.00") && (fields[8] != "" || fields[8])){
        std::string Speed = fields[7];
        std::string COG = fields[8];
	}
	if (fields[9] != "")
        std::string Date = fields[9];
    }	
	if (Speed != "0.00" && (COG != "" || COG != "0.00")){
        // Print or use the extracted values
        std::cout << "RMC Data:" << std::endl;
        std::cout << "  Speed: " << Speed << std::endl;
        std::cout << "  COG: " << COG << std::endl;
        std::cout << "  Date: " << Date << std::endl;
	}
    } else {
        std::cerr << "Invalid RMC line: " << line << std::endl;
    }
}


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
       			if (result.find("GGA") != std::string::npos) {
            			processGGA(result);
        		} 
			if (result.find("RMC") != std::string::npos) {
            			processRMC(result);
			}
		result = '\n';
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
   //std::cout << result << std::endl;
    
    return 0;
}
