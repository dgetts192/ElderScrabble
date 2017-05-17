using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Scrabble.Models
{
    public partial class ScrabbleContext : DbContext
    {
        public ScrabbleContext(DbContextOptions<ScrabbleContext> options) : base(options) { }

        public virtual DbSet<Email> Email { get; set; }
        public virtual DbSet<Location> Location { get; set; }
        public virtual DbSet<Match> Match { get; set; }
        public virtual DbSet<Member> Member { get; set; }
        public virtual DbSet<Person> Person { get; set; }
        public virtual DbSet<Telephone> Telephone { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Email>(entity =>
            {
                entity.Property(e => e.Address)
                    .IsRequired()
                    .HasMaxLength(150);

                entity.HasOne(d => d.Member)
                    .WithMany(p => p.Email)
                    .HasForeignKey(d => d.MemberId)
                    .OnDelete(DeleteBehavior.Restrict)
                    .HasConstraintName("FK_Member_Email");
            });

            modelBuilder.Entity<Location>(entity =>
            {
                entity.Property(e => e.Latitude).HasColumnType("decimal");

                entity.Property(e => e.Longitude).HasColumnType("decimal");

                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(50);
            });

            modelBuilder.Entity<Match>(entity =>
            {
                entity.Property(e => e.DatePlayed).HasColumnType("date");

                entity.HasOne(d => d.Location)
                    .WithMany(p => p.Match)
                    .HasForeignKey(d => d.LocationId)
                    .OnDelete(DeleteBehavior.Restrict)
                    .HasConstraintName("FK_Match_Location");

                entity.HasOne(d => d.PlayerOne)
                    .WithMany(p => p.MatchPlayerOne)
                    .HasForeignKey(d => d.PlayerOneId)
                    .OnDelete(DeleteBehavior.Restrict)
                    .HasConstraintName("FK_Match_PlayerOne");

                entity.HasOne(d => d.PlayerTwo)
                    .WithMany(p => p.MatchPlayerTwo)
                    .HasForeignKey(d => d.PlayerTwoId)
                    .OnDelete(DeleteBehavior.Restrict)
                    .HasConstraintName("FK_Match_PlayerTwo");
            });

            modelBuilder.Entity<Member>(entity =>
            {
                entity.Property(e => e.Id).ValueGeneratedNever();

                entity.Property(e => e.DateJoined).HasColumnType("date");

                entity.HasOne(d => d.IdNavigation)
                    .WithOne(p => p.Member)
                    .HasForeignKey<Member>(d => d.Id)
                    .OnDelete(DeleteBehavior.Restrict)
                    .HasConstraintName("FK_Person_Member");
            });

            modelBuilder.Entity<Person>(entity =>
            {
                entity.Property(e => e.DateOfBirth)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.FirstName)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.LastName)
                    .IsRequired()
                    .HasMaxLength(50);
            });

            modelBuilder.Entity<Telephone>(entity =>
            {
                entity.Property(e => e.Number)
                    .IsRequired()
                    .HasMaxLength(13);

                entity.HasOne(d => d.Member)
                    .WithMany(p => p.Telephone)
                    .HasForeignKey(d => d.MemberId)
                    .OnDelete(DeleteBehavior.Restrict)
                    .HasConstraintName("FK_Member_Telephone");
            });
        }
    }
}