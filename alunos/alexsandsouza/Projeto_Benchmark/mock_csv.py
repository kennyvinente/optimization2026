import csv
import random

problems = ["arki0003", "arki0009", "bearing_400", "camshape_64", "elec_200", "elec_400", "gasoil_3200", "lukvle5", "marine_800", "robot_1600", "cont5_2_1_l", "qcqp500-2c"]
solvers = ["Ipopt", "MadNLP", "NLopt", "Optim", "Uno"]

with open("benchmark_results.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Problem", "Solver", "Time_sec", "Iterations", "Status", "Objective"])
    for p in problems:
        for s in solvers:
            time_sec = round(random.uniform(0.1, 5.5), 4)
            iters = random.randint(15, 120)
            obj = round(random.uniform(-100, 5000), 4)
            
            # Simulated edge cases
            if s == "Optim" and "qcqp" in p:
                status = "ITERATION_LIMIT"
                iters = 1000
                obj = "NaN"
            else:
                status = "LOCALLY_SOLVED"
                
            writer.writerow([p, s, time_sec, iters, status, obj])
