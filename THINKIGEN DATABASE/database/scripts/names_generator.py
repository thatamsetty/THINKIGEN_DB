import os
import sys
import random

# Generate realistic, authentic Indian names
MALE_FIRST_NAMES = [
    "Aarav", "Vihaan", "Vivaan", "Arjun", "Reyansh", "Muhammad", "Sai", "Arnav", "Aayan", "Krishna",
    "Ishan", "Shaurya", "Atharva", "Advik", "Pranav", "Advaith", "Aryan", "Dhruv", "Kabir", "Ritvik",
    "Darsh", "Aniket", "Harshit", "Samarth", "Manan", "Yuvan", "Parth", "Krrish", "Dev", "Bhavin",
    "Tanish", "Yatharth", "Tejas", "Rishabh", "Ronit", "Ayush", "Siddharth", "Yash", "Varun", "Madhav",
    "Chirag", "Tanmay", "Rohan", "Nikhil", "Abhimanyu", "Chetan", "Daksh", "Eklavya", "Hardik", "Jayant",
    "Keshav", "Lakshya", "Mayank", "Nakul", "Om", "Pratyush", "Raghav", "Samar", "Utkarsh", "Vedant",
    "Wahid", "Yuvraj", "Zayan", "Agastya", "Bhuvan", "Chaitanya", "Devesh", "Farhan", "Gautam", "Hitesh",
    "Indrajit", "Jatin", "Kushagra", "Lokesh", "Mohit", "Naman", "Ojas", "Piyush", "Raghunath", "Sahil",
    "Tarun", "Uday", "Veer", "Zeeshan", "Abhiram", "Balram", "Chandan", "Dinesh", "Eashan", "Ganesh",
    "Hemant", "Ishwar", "Jagdish", "Kalyan", "Lalit", "Mahesh", "Naveen", "Pavan", "Rajesh", "Suresh",
    "Abhay", "Akash", "Amrit", "Anand", "Ansh", "Anuj", "Ashish", "Avinash", "Bharat", "Deepak",
    "Devendra", "Dilip", "Girish", "Hari", "Harish", "Himanshu", "Jitendra", "Kamal", "Karan", "Kartik",
    "Kishore", "Kunal", "Manish", "Manoj", "Mukul", "Mukesh", "Nitin", "Pankaj", "Pradeep", "Prakash",
    "Prashant", "Praveen", "Prem", "Rahul", "Rajiv", "Rakesh", "Raman", "Ramesh", "Ravi", "Ravindra",
    "Sachin", "Sameer", "Sanjay", "Sanjeev", "Santosh", "Sarvesh", "Satish", "Saurabh", "Shailesh", "Shankar",
    "Sharad", "Shashank", "Shivam", "Subhash", "Sudhir", "Sumit", "Sunder", "Sunil", "Suraj", "Surendra",
    "Surya", "Swapnil", "Umesh", "Vaibhav", "Vasant", "Vijay", "Vikas", "Vikram", "Vinay", "Vinod",
    "Vipul", "Vishal", "Vishnu", "Vivek", "Abhijeet", "Adhiraj", "Akshat", "Alok", "Amol", "Anupam",
    "Anuraag", "Apoorv", "Arpit", "Ashok", "Atul", "Bhavesh", "Brijesh", "Chinmay", "Dhananjay", "Divyansh",
    "Gaurav", "Gopichand", "Gurpreet", "Harbhajan", "Harpreet", "Inderjit", "Jaspreet", "Kuldeep", "Manpreet", "Navneet"
]

FEMALE_FIRST_NAMES = [
    "Aadhya", "Ananya", "Pari", "Anika", "Navya", "Angel", "Diya", "Myra", "Sara", "Ira",
    "Ahana", "Anvi", "Prisha", "Riya", "Aarohi", "Anaya", "Shanaya", "Kavya", "Avni", "Sneha",
    "Ishita", "Meera", "Riddhi", "Tanya", "Siya", "Disha", "Kiara", "Pihu", "Tanvi", "Khushi",
    "Mahi", "Nandini", "Trisha", "Shreya", "Samiksha", "Aditi", "Kashvi", "Charvi", "Mansi", "Vidhi",
    "Bhavya", "Kriti", "Poorvi", "Swara", "Dhriti", "Jiya", "Lavanya", "Mridula", "Niharika", "Ovi",
    "Paavni", "Radhika", "Sanjana", "Tara", "Urvi", "Veda", "Yashvi", "Zara", "Akshara", "Barkha",
    "Chetna", "Damini", "Gargi", "Harini", "Isha", "Juhi", "Kalyani", "Leela", "Malini", "Nidhi",
    "Payal", "Rashmi", "Sanya", "Tripti", "Upasana", "Vandana", "Yamini", "Aastha", "Bindu", "Chitra",
    "Divya", "Ekta", "Gauri", "Hema", "Indu", "Jaya", "Karuna", "Lata", "Madhuri", "Neha",
    "Pooja", "Rekha", "Sarita", "Tulsi", "Urmila", "Vani", "Aparna", "Archana", "Aruna", "Asha",
    "Babita", "Beena", "Bela", "Chhaya", "Deepa", "Deepika", "Geeta", "Geetika", "Jyoti", "Kamla",
    "Kanchan", "Kiran", "Komal", "Kusum", "Laxmi", "Madhu", "Mamta", "Manju", "Maya", "Meena",
    "Meenakshi", "Mohini", "Mukta", "Nalini", "Namrata", "Neelam", "Neeru", "Nirmala", "Nisha", "Pallavi",
    "Poonam", "Prabha", "Pratibha", "Preeti", "Pushpa", "Rachna", "Rajni", "Rani", "Reena", "Renu",
    "Richa", "Ritu", "Roopa", "Roshni", "Ruchi", "Sadhana", "Sandhya", "Sangeeta", "Sapna", "Seema",
    "Shalini", "Sharda", "Sheetal", "Shikha", "Shilpa", "Shobha", "Smita", "Sonal", "Sonia", "Sudha",
    "Suman", "Sunita", "Sushma", "Swati", "Uma", "Usha", "Varsha", "Veena", "Vibhuti", "Vijaya",
    "Alaknanda", "Amrita", "Anamika", "Anindita", "Ankita", "Anuradha", "Apsara", "Avani", "Bimla", "Chandni"
]

SURNAMES = [
    "Sharma", "Varma", "Reddy", "Patel", "Gupta", "Kumar", "Singh", "Rao", "Nair", "Iyer",
    "Das", "Joshi", "Mehta", "Sen", "Deshmukh", "Kulkarni", "Bhat", "Pillai", "Banerjee", "Mukherjee",
    "Chatterjee", "Bose", "Dutta", "Ghosh", "Roy", "Menon", "Nambiar", "Shetty", "Hegde", "Pai",
    "Choudhury", "Mishra", "Pandey", "Tiwari", "Shukla", "Dubey", "Tripathi", "Pathak", "Ojha", "Jha",
    "Thakur", "Chauhan", "Rathore", "Solanki", "Parmar", "Rajput", "Yadav", "Saini", "Chaudhary", "Malik",
    "Gill", "Dhillon", "Sandhu", "Sidhu", "Grewal", "Bajwa", "Bedi", "Chopra", "Khanna", "Kapoor",
    "Malhotra", "Grover", "Sethi", "Tandon", "Anand", "Kohli", "Narang", "Bhatia", "Walia", "Sachdeva",
    "Saxena", "Mathur", "Srivastava", "Nigam", "Asthana", "Kulshrestha", "Bhatnagar", "Agarwal", "Goel", "Mittal",
    "Garg", "Bansal", "Singhal", "Kansal", "Mahajan", "Khatri", "Suri", "Talwar", "Bhandari", "Chawla",
    "Ghai", "Sodhi", "Bakshi", "Lamba", "Trehan", "Mehra", "Uppal", "Madan", "Nagpal", "Munjal",
    "Kashyap", "Gowda", "Naidu", "Chowdary", "Raju", "Venkatesh", "Prasad", "Subramanian", "Balakrishnan", "Krishnan",
    "Raman", "Narayanan", "Ganesan", "Srinivasan", "Raghavan", "Venkataraman", "Viswanathan", "Ananthakrishnan", "Sundaram", "Swaminathan",
    "Bhardwaj", "Kaushik", "Vashist", "Gautam", "Upadhyay", "Awasthi", "Dwivedi", "Vaidya", "Sastry", "Somayaji",
    "Acharya", "Bhattacharya", "Chakraborty", "Ganguly", "Goswami", "Majumdar", "Mitra", "Sanyal", "Sengupta", "Bhowmick"
]

def build_unique_names():
    active_student_names = []
    used_full_names = set()

    for i in range(200):
        fname = MALE_FIRST_NAMES[i % len(MALE_FIRST_NAMES)]
        sname = SURNAMES[(i * 3 + 1) % len(SURNAMES)]
        full = f"{fname} {sname}"
        counter = 1
        while full in used_full_names:
            sname = SURNAMES[(i * 3 + counter) % len(SURNAMES)]
            full = f"{fname} {sname}"
            counter += 1
        used_full_names.add(full)
        active_student_names.append((fname, sname, "MALE"))

    for i in range(200):
        fname = FEMALE_FIRST_NAMES[i % len(FEMALE_FIRST_NAMES)]
        sname = SURNAMES[(i * 3 + 2) % len(SURNAMES)]
        full = f"{fname} {sname}"
        counter = 1
        while full in used_full_names:
            sname = SURNAMES[(i * 3 + counter + 10) % len(SURNAMES)]
            full = f"{fname} {sname}"
            counter += 1
        used_full_names.add(full)
        active_student_names.append((fname, sname, "FEMALE"))

    random.seed(42)
    random.shuffle(active_student_names)

    teacher_names = []
    for i in range(80):
        if i % 2 == 0:
            fname = MALE_FIRST_NAMES[(i + 50) % len(MALE_FIRST_NAMES)]
            gender = "MALE"
        else:
            fname = FEMALE_FIRST_NAMES[(i + 50) % len(FEMALE_FIRST_NAMES)]
            gender = "FEMALE"
        sname = SURNAMES[(i * 2 + 15) % len(SURNAMES)]
        full = f"{fname} {sname}"
        while full in used_full_names:
            sname = SURNAMES[(i * 2 + 25) % len(SURNAMES)]
            full = f"{fname} {sname}"
        used_full_names.add(full)
        teacher_names.append((fname, sname, gender))

    alumni_names = []
    for i in range(20):
        if i % 2 == 0:
            fname = MALE_FIRST_NAMES[(i + 120) % len(MALE_FIRST_NAMES)]
            gender = "MALE"
        else:
            fname = FEMALE_FIRST_NAMES[(i + 120) % len(FEMALE_FIRST_NAMES)]
            gender = "FEMALE"
        sname = SURNAMES[(i * 4 + 40) % len(SURNAMES)]
        full = f"{fname} {sname}"
        while full in used_full_names:
            sname = SURNAMES[(i * 4 + 50) % len(SURNAMES)]
            full = f"{fname} {sname}"
        used_full_names.add(full)
        alumni_names.append((fname, sname, gender))

    return active_student_names, teacher_names, alumni_names
