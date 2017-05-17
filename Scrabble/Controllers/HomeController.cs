using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Scrabble.Models;
using Scrabble.Repositories;

namespace Scrabble.Controllers
{
    public class HomeController : Controller
    {
        private readonly IScrabbleRepository repository;

        public HomeController(IScrabbleRepository repository)
        {
            this.repository = repository;
        }

        public async Task<IActionResult> Index()
        {
            var leaderboard = await repository.GetLeaderboard();
            return View(leaderboard);
        }       

        public async Task<IActionResult> Profile(int id)
        {
            var profile = await repository.GetMemberProfile(id);
            return View(profile);
        }

        public IActionResult Error()
        {
            return View();
        }
    }
}
