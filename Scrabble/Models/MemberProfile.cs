using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Scrabble.Models
{
    public class MemberProfile
    {
        public int PlayerId { get; set; }
        public string PlayerName { get; set; }
        public DateTime DateOfBirth { get; set; }
        public string TelephoneNumber { get; set; }
        public string EmailAddress { get; set; }
        public int WinCount { get; set; }
        public int LossCount { get; set; }
        public int AverageScore { get; set; }
        public int HighestScore { get; set; }
        public DateTime HighestDatePlayed { get; set; }
        public int HighestOpponentId { get; set; }
        public string HighestOpponentName { get; set; }
        public string HighestLocation { get; set; }
        public decimal HighestLongitude { get; set; }
        public decimal HighestLatitude { get; set; }
    }
}
