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
            ?? User.FindFirst("sub")?.Value
            ?? User.FindFirst("preferred_username")?.Value;
    }

    private bool IsUserAuthentication()
    {
        // Check if token has session_state claim (only present in user authentication)
        return User.HasClaim(c => c.Type == "sid" || c.Type == "session_state");
    }

    [HttpGet]
    [Authorize(Policy = "list-todos")]
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
    [Authorize(Policy = "read-todo")]
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
    [Authorize(Policy = "create-todo")]
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
    [Authorize(Policy = "update-todo")]
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
    [Authorize(Policy = "delete-todo")]
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
