#!/bin/bash

task_file="tasks.csv"

trap 'rm -f temp.csv' EXIT

if [ ! -f "$task_file" ]; then
    touch "$task_file"
fi

generate_id() {
    if [ ! -s "$task_file" ]; then
        echo 1
    else
        last_id=$(tail -n 1 "$task_file" | cut -d',' -f1)
        echo $((last_id + 1))
    fi
}

add_task() {
    echo "Enter task title:"
    read title

    if [ -z "$title" ]; then
        echo "Error: Title cannot be empty!"
        return
    fi

    echo "Enter task date (YYYY-MM-DD) or press Enter to skip:"
    read date

    if [ -z "$date" ]; then
        date="N/A"
    fi

    if [[ "$date" != "N/A" && ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Error: Invalid date format! Use YYYY-MM-DD"
        return
    fi

    id=$(generate_id)
    echo "$id,$title,Pending,$date" >> "$task_file"
    echo "Task added successfully! (ID: $id)"
}

view_tasks() {
    if [ ! -s "$task_file" ]; then
        echo "No tasks found."
        return
    fi

    mapfile -t tasks < "$task_file"

    echo ""
    echo "================================================================"
    printf "%-5s | %-25s | %-12s | %-12s\n" "ID" "TITLE" "STATUS" "DATE"
    echo "================================================================"

    for task in "${tasks[@]}"; do
        IFS=',' read -r id title status date <<< "$task"
        printf "%-5s | %-25s | %-12s | %-12s\n" "$id" "$title" "$status" "$date"
    done

    echo "================================================================"
    echo "Total tasks: ${#tasks[@]}"
}

delete_task() {
    if [ ! -s "$task_file" ]; then
        echo "No tasks found."
        return
    fi

    view_tasks

    echo "Enter task ID to delete:"
    read delete_id

    if [[ ! "$delete_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Please enter a valid numeric ID!"
        return
    fi

    if grep -q "^$delete_id," "$task_file"; then
        grep -v "^$delete_id," "$task_file" > temp.csv
        mv temp.csv "$task_file"
        echo "Task $delete_id deleted successfully!"
    else
        echo "Error: Task ID $delete_id not found!"
    fi
}

mark_completed() {
    if [ ! -s "$task_file" ]; then
        echo "No tasks found."
        return
    fi

    view_tasks

    echo "Enter task ID to mark as completed:"
    read complete_id

    if [[ ! "$complete_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Please enter a valid numeric ID!"
        return
    fi

    if grep -q "^$complete_id," "$task_file"; then

        current_status=$(grep "^$complete_id," "$task_file" | cut -d',' -f3)
        if [ "$current_status" = "Completed" ]; then
            echo "Task $complete_id is already marked as completed!"
            return
        fi

        while IFS=',' read -r id title status date
        do
            if [ "$id" = "$complete_id" ]; then
                echo "$id,$title,Completed,$date" >> temp.csv
            else
                echo "$id,$title,$status,$date" >> temp.csv
            fi
        done < "$task_file"

        mv temp.csv "$task_file"
        echo "Task $complete_id marked as completed!"
    else
        echo "Error: Task ID $complete_id not found!"
    fi
}

edit_task() {
    if [ ! -s "$task_file" ]; then
        echo "No tasks found."
        return
    fi

    view_tasks

    echo "Enter task ID to edit:"
    read edit_id

    if [[ ! "$edit_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Please enter a valid numeric ID!"
        return
    fi

    if grep -q "^$edit_id," "$task_file"; then

        while IFS=',' read -r id title status date
        do
            if [ "$id" = "$edit_id" ]; then

                echo "Current title: $title"
                echo "Enter new title (or press Enter to keep current):"
                read new_title
                if [ -z "$new_title" ]; then
                    new_title="$title"
                fi

                echo "Current date: $date"
                echo "Enter new date YYYY-MM-DD (or press Enter to keep current):"
                read new_date
                if [ -z "$new_date" ]; then
                    new_date="$date"
                fi

                if [[ "$new_date" != "N/A" && ! "$new_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    echo "Error: Invalid date format! Task not updated."
                    rm -f temp.csv
                    return
                fi

                echo "Current status: $status"
                echo "Enter new status (Pending/Completed) or press Enter to keep current:"
                read new_status
                if [ -z "$new_status" ]; then
                    new_status="$status"
                fi

                if [[ "$new_status" != "Pending" && "$new_status" != "Completed" ]]; then
                    echo "Error: Status must be 'Pending' or 'Completed'! Task not updated."
                    rm -f temp.csv
                    return
                fi

                echo "$id,$new_title,$new_status,$new_date" >> temp.csv
            else
                echo "$id,$title,$status,$date" >> temp.csv
            fi
        done < "$task_file"

        mv temp.csv "$task_file"
        echo "Task $edit_id updated successfully!"
    else
        echo "Error: Task ID $edit_id not found!"
    fi
}

search_tasks() {
    if [ ! -s "$task_file" ]; then
        echo "No tasks found."
        return
    fi

    echo "Enter keyword to search:"
    read keyword

    if [ -z "$keyword" ]; then
        echo "Error: Keyword cannot be empty!"
        return
    fi

    mapfile -t results < <(grep -i "$keyword" "$task_file")

    if [ ${#results[@]} -eq 0 ]; then
        echo "No tasks found matching: '$keyword'"
        return
    fi

    echo ""
    echo "================================================================"
    printf "%-5s | %-25s | %-12s | %-12s\n" "ID" "TITLE" "STATUS" "DATE"
    echo "================================================================"

    for task in "${results[@]}"; do
        IFS=',' read -r id title status date <<< "$task"
        printf "%-5s | %-25s | %-12s | %-12s\n" "$id" "$title" "$status" "$date"
    done

    echo "================================================================"
    echo "Found: ${#results[@]} matching task(s)"
}

while true
do
    echo ""
    echo "========================================="
    echo "          TO-DO LIST APPLICATION         "
    echo "========================================="
    echo "  1. Add Task"
    echo "  2. View All Tasks"
    echo "  3. Edit Task"
    echo "  4. Delete Task"
    echo "  5. Mark Task as Completed"
    echo "  6. Search Tasks"
    echo "  7. Exit"
    echo "========================================="
    echo "Enter your choice:"
    read choice

    choice=$(echo "$choice" | tr -d '[:space:]')

    case $choice in
        1)
            add_task
            ;;
        2)
            view_tasks
            ;;
        3)
            edit_task
            ;;
        4)
            delete_task
            ;;
        5)
            mark_completed
            ;;
        6)
            search_tasks
            ;;
        7)
            echo "Goodbye! Exiting program..."
            exit 0
            ;;
        *)
            echo "Error: Invalid choice! Please enter a number from 1 to 7."
            ;;
    esac
done
