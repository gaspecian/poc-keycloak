using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TodoBackend.Data;
using TodoBackend.Models;

namespace TodoBackend.Controllers;

[Authorize]
[ApiController]
[Route("api/todos")]
public class TodoController : ControllerBase
{
    private readonly TodoDbContext _context;

    public TodoController(TodoDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Todo>>> GetTodos()
    {
        return await _context.Todos.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Todo>> GetTodo(int id)
    {
        var todo = await _context.Todos.FindAsync(id);
        if (todo == null)
            return NotFound();

        return todo;
    }

    [HttpPost]
    public async Task<ActionResult<Todo>> CreateTodo(CreateTodoDto dto)
    {
        var todo = new Todo
        {
            Title = dto.Title,
            Description = dto.Description,
            IsCompleted = false
        };

        _context.Todos.Add(todo);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetTodo), new { id = todo.Id }, todo);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateTodo(int id, UpdateTodoDto dto)
    {
        var todo = await _context.Todos.FindAsync(id);
        if (todo == null)
            return NotFound();

        todo.Title = dto.Title;
        todo.Description = dto.Description;
        todo.IsCompleted = dto.IsCompleted;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteTodo(int id)
    {
        var todo = await _context.Todos.FindAsync(id);
        if (todo == null)
            return NotFound();

        _context.Todos.Remove(todo);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public record CreateTodoDto(string Title, string? Description);
public record UpdateTodoDto(string Title, string? Description, bool IsCompleted);
