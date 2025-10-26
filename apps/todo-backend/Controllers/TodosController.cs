using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TodoBackend.Data;
using TodoBackend.Models;
using System.Security.Claims;

namespace TodoBackend.Controllers;

[Authorize]
[ApiController]
[Route("api/todos")]
public class TodosController : ControllerBase
{
    private readonly TodoDbContext _context;

    public TodosController(TodoDbContext context)
    {
        _context = context;
    }

    private string? GetUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
            ?? User.FindFirst("sub")?.Value;
    }

    private bool IsUserAuthentication()
    {
        var userId = GetUserId();
        return !string.IsNullOrEmpty(userId) && !User.HasClaim("client_id", "todo-backend-client");
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Todo>>> GetTodos()
    {
        var query = _context.Todos.AsQueryable();
        
        if (IsUserAuthentication())
        {
            var userId = GetUserId()!;
            query = query.Where(t => t.UserId == userId);
        }

        return await query.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Todo>> GetTodo(int id)
    {
        var query = _context.Todos.Where(t => t.Id == id);
        
        if (IsUserAuthentication())
        {
            var userId = GetUserId()!;
            query = query.Where(t => t.UserId == userId);
        }

        var todo = await query.FirstOrDefaultAsync();

        if (todo == null)
            return NotFound();

        return todo;
    }

    [HttpPost]
    public async Task<ActionResult<Todo>> CreateTodo(CreateTodoDto dto)
    {
        var userId = GetUserId() ?? "system";
        
        var todo = new Todo
        {
            Title = dto.Title,
            Description = dto.Description,
            IsCompleted = false,
            CreatedAt = DateTime.UtcNow,
            UserId = userId
        };

        _context.Todos.Add(todo);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetTodo), new { id = todo.Id }, todo);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateTodo(int id, UpdateTodoDto dto)
    {
        var query = _context.Todos.Where(t => t.Id == id);
        
        if (IsUserAuthentication())
        {
            var userId = GetUserId()!;
            query = query.Where(t => t.UserId == userId);
        }

        var todo = await query.FirstOrDefaultAsync();

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
        var query = _context.Todos.Where(t => t.Id == id);
        
        if (IsUserAuthentication())
        {
            var userId = GetUserId()!;
            query = query.Where(t => t.UserId == userId);
        }

        var todo = await query.FirstOrDefaultAsync();

        if (todo == null)
            return NotFound();

        _context.Todos.Remove(todo);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public record CreateTodoDto(string Title, string? Description);
public record UpdateTodoDto(string Title, string? Description, bool IsCompleted);
