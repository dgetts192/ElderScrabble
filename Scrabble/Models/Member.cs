using System;
using System.Collections.Generic;

namespace Scrabble.Models
{
    public partial class Member
    {
        public Member()
        {
            Email = new HashSet<Email>();
            MatchPlayerOne = new HashSet<Match>();
            MatchPlayerTwo = new HashSet<Match>();
            Telephone = new HashSet<Telephone>();
        }

        public int Id { get; set; }
        public DateTime DateJoined { get; set; }

        public virtual ICollection<Email> Email { get; set; }
        public virtual ICollection<Match> MatchPlayerOne { get; set; }
        public virtual ICollection<Match> MatchPlayerTwo { get; set; }
        public virtual ICollection<Telephone> Telephone { get; set; }
        public virtual Person IdNavigation { get; set; }
    }
}
