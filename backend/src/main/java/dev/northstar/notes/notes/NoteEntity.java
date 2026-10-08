package dev.northstar.notes.notes;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
@Entity
@Table(name = "notes")
@Getter
@Setter
@NoArgsConstructor
public class NoteEntity {
  @Id
  private UUID id = UUID.randomUUID();
  @Column(name = "owner_id", nullable = false)
  private UUID ownerId;
  @Column(name = "folder_id", nullable = false)
  private UUID folderId;
  @Column(nullable = false, length = 200)
  private String title = "Untitled";
  @Column(nullable = false, columnDefinition = "TEXT")
  private String body = "";
  @ElementCollection(fetch = FetchType.EAGER)
  @CollectionTable(name = "note_tags", joinColumns = @JoinColumn(name = "note_id"))
  @Column(name = "tag", length = 50)
  @org.hibernate.annotations.BatchSize(size = 100)
  private Set<String> tags = new HashSet<>();
  @Column(name = "is_favorite", nullable = false)
  private boolean favorite = false;
  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 16)
  private NoteStatus status = NoteStatus.active;
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt = Instant.now();
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt = Instant.now();
}
