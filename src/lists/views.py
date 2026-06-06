from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404, redirect, render

from lists.forms import TodoForm, TodoListForm
from lists.models import Todo, TodoList


def index(request):
    return render(request, "lists/index.html", {"form": TodoListForm()})


def todolist(request, todolist_id):
    todolist = get_object_or_404(TodoList, pk=todolist_id)

    session_lists = request.session.get("anonymous_lists", [])
    is_owner = (
        request.user.is_authenticated and todolist.creator == request.user
    ) or (todolist_id in session_lists)

    if not is_owner:
        return redirect("lists:index")

    if request.method == "POST":
        if "title" in request.POST:
            list_form = TodoListForm(request.POST)
            if list_form.is_valid():
                todolist.title = list_form.cleaned_data["title"]
                todolist.save()
                return redirect("lists:todolist", todolist_id=todolist.id)
        else:
            return redirect("lists:add_todo", todolist_id=todolist_id)

    return render(
        request,
        "lists/todolist.html",
        {
            "todolist": todolist,
            "form": TodoForm(),
            "list_form": TodoListForm(initial={"title": todolist.title}),
        },
    )


def add_todo(request, todolist_id):
    if request.method == "POST":
        form = TodoForm(request.POST)
        if form.is_valid():
            user = request.user if request.user.is_authenticated else None
            todo = Todo(
                description=request.POST["description"],
                todolist_id=todolist_id,
                creator=user,
            )
            todo.save()
            return redirect("lists:todolist", todolist_id=todolist_id)
        else:
            return render(request, "lists/todolist.html", {"form": form})

    return redirect("lists:index")


@login_required
def overview(request):
    return render(request, "lists/overview.html", {"form": TodoListForm()})


def new_todolist(request):
    if request.method == "POST":
        form = TodoListForm(request.POST)
        if form.is_valid():
            user = request.user if request.user.is_authenticated else None
            todolist = TodoList(
                title=form.cleaned_data["title"],
                creator=user,
            )
            todolist.save()

            if user is None:
                session_lists = request.session.get("anonymous_lists", [])
                session_lists.append(todolist.id)
                request.session["anonymous_lists"] = session_lists
                request.session.modified = True

            return redirect("lists:todolist", todolist_id=todolist.id)
        else:
            return render(request, "lists/index.html", {"form": form})

    return redirect("lists:index")


def add_todolist(request):
    if request.method == "POST":
        form = TodoListForm(request.POST)
        if form.is_valid():
            user = request.user if request.user.is_authenticated else None
            todolist = TodoList(title=form.cleaned_data["title"], creator=user)
            todolist.save()
            return redirect("lists:todolist", todolist_id=todolist.id)
        else:
            return render(request, "lists/overview.html", {"form": form})

    return redirect("lists:index")