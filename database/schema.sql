 -- Tech Company AI Use Cases Database Schema - PostgreSQL Version
-- Optimized for Render PostgreSQL + n8n workflows + Python processing

-- =====================================================
-- CORE TAXONOMY (Company-Agnostic Patterns)
-- =====================================================

-- Main use case patterns table (the core taxonomy)
CREATE TABLE use_case_patterns (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    summary TEXT,
    
    -- Categorization (company-agnostic)
    company_type VARCHAR(50),
    department VARCHAR(50),
    role VARCHAR(100),
    business_function VARCHAR(100),
    ai_category VARCHAR(50),
    
    -- Implementation guidance (generic)
    implementation_approach TEXT,
    typical_tech_stack JSONB,              -- PostgreSQL JSON type
    difficulty_level VARCHAR(20),
    prerequisites TEXT,
    
    -- Expected outcomes (generic)
    expected_outcomes TEXT,
    success_metrics JSONB,                 -- PostgreSQL JSON type
    
    -- Company examples (supporting evidence)
    company_examples JSONB,                -- PostgreSQL JSON type
    total_example_count INTEGER DEFAULT 0,
    
    -- Data quality and processing
    content_quality_score INTEGER,
    extraction_confidence DECIMAL(3,2),    -- PostgreSQL decimal type
    pattern_verified BOOLEAN DEFAULT FALSE,
    
    -- Processing status
    classification_status VARCHAR(20) DEFAULT 'pending',
    similarity_processed BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- RAW SOURCE DATA (What n8n scrapes)
-- =====================================================

-- Raw scraped content before processing into patterns
CREATE TABLE raw_scraped_content (
    id SERIAL PRIMARY KEY,
    
    -- Raw content
    title VARCHAR(255),
    description TEXT,
    full_content TEXT,
    
    -- Source company context
    company_name VARCHAR(100),
    company_type VARCHAR(50),
    company_size VARCHAR(20),
    
    -- Source metadata
    source_name VARCHAR(100) NOT NULL,
    source_url VARCHAR(500) NOT NULL,
    source_type VARCHAR(50),
    
    -- Processing status
    processing_status VARCHAR(20) DEFAULT 'pending',
    assigned_pattern_id INTEGER REFERENCES use_case_patterns(id),
    
    -- Quality metrics
    content_quality_score INTEGER,
    extraction_errors JSONB,               -- PostgreSQL JSON type
    
    -- Timestamps
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- TAXONOMY STRUCTURE
-- =====================================================

-- Company types taxonomy
CREATE TABLE company_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES company_types(id),
    typical_departments JSONB
);

-- Departments taxonomy
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    typical_roles JSONB
);

-- Business functions taxonomy
CREATE TABLE business_functions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(50),
    description TEXT,
    department_id INTEGER REFERENCES departments(id),
    typical_ai_categories JSONB
);

-- AI categories taxonomy
CREATE TABLE ai_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    technical_complexity VARCHAR(20),
    common_use_cases JSONB
);

-- =====================================================
-- RELATIONSHIPS & SIMILARITY
-- =====================================================

-- Pattern similarities
CREATE TABLE pattern_similarities (
    id SERIAL PRIMARY KEY,
    pattern_1_id INTEGER NOT NULL REFERENCES use_case_patterns(id),
    pattern_2_id INTEGER NOT NULL REFERENCES use_case_patterns(id),
    similarity_score DECIMAL(3,2) NOT NULL,
    similarity_type VARCHAR(20),
    reasoning TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(pattern_1_id, pattern_2_id)
);

-- Tags for flexible categorization
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(30),
    description TEXT,
    usage_count INTEGER DEFAULT 0
);

-- Many-to-many relationship for pattern tags
CREATE TABLE pattern_tags (
    pattern_id INTEGER REFERENCES use_case_patterns(id),
    tag_id INTEGER REFERENCES tags(id),
    confidence DECIMAL(3,2) DEFAULT 1.0,
    PRIMARY KEY (pattern_id, tag_id)
);

-- =====================================================
-- SOURCE MANAGEMENT & SCRAPING
-- =====================================================

-- Track scraping sources
CREATE TABLE scraping_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    base_url VARCHAR(255) NOT NULL,
    source_type VARCHAR(50),
    
    -- Scraping configuration
    scraping_config JSONB,
    content_selectors JSONB,
    last_scraped_at TIMESTAMP WITH TIME ZONE,
    next_scrape_at TIMESTAMP WITH TIME ZONE,
    scraping_enabled BOOLEAN DEFAULT TRUE,
    
    -- Quality metrics
    success_rate DECIMAL(3,2) DEFAULT 1.0,
    avg_quality_score DECIMAL(3,2),
    total_content_scraped INTEGER DEFAULT 0,
    patterns_generated INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Track individual scraping runs
CREATE TABLE scraping_runs (
    id SERIAL PRIMARY KEY,
    source_id INTEGER REFERENCES scraping_sources(id),
    
    -- Run details
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20),
    
    -- Results
    items_found INTEGER DEFAULT 0,
    items_processed INTEGER DEFAULT 0,
    items_stored INTEGER DEFAULT 0,
    patterns_created INTEGER DEFAULT 0,
    errors_count INTEGER DEFAULT 0,
    
    -- Metadata
    n8n_execution_id VARCHAR(100),
    error_details JSONB,
    performance_metrics JSONB
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Core search indexes for patterns
CREATE INDEX idx_patterns_company_type ON use_case_patterns(company_type);
CREATE INDEX idx_patterns_department ON use_case_patterns(department);
CREATE INDEX idx_patterns_role ON use_case_patterns(role);
CREATE INDEX idx_patterns_ai_category ON use_case_patterns(ai_category);
CREATE INDEX idx_patterns_difficulty ON use_case_patterns(difficulty_level);
CREATE INDEX idx_patterns_quality ON use_case_patterns(content_quality_score);

-- Raw content indexes
CREATE INDEX idx_raw_content_company ON raw_scraped_content(company_name);
CREATE INDEX idx_raw_content_source ON raw_scraped_content(source_name);
CREATE INDEX idx_raw_content_status ON raw_scraped_content(processing_status);

-- JSON/JSONB indexes for fast searching
CREATE INDEX idx_patterns_company_examples_gin ON use_case_patterns USING GIN (company_examples);
CREATE INDEX idx_patterns_tech_stack_gin ON use_case_patterns USING GIN (typical_tech_stack);

-- Full-text search indexes
CREATE INDEX idx_patterns_title_fts ON use_case_patterns USING GIN (to_tsvector('english', title));
CREATE INDEX idx_patterns_description_fts ON use_case_patterns USING GIN (to_tsvector('english', description));

-- Similarity indexes
CREATE INDEX idx_similarities_score ON pattern_similarities(similarity_score DESC);
CREATE INDEX idx_similarities_pattern_1 ON pattern_similarities(pattern_1_id);

-- Source tracking indexes
CREATE INDEX idx_scraping_runs_source ON scraping_runs(source_id);
CREATE INDEX idx_scraping_runs_status ON scraping_runs(status);
CREATE INDEX idx_scraping_runs_date ON scraping_runs(started_at);

-- =====================================================
-- INITIAL SEED DATA
-- =====================================================

-- Insert tech company types
INSERT INTO company_types (name, description, typical_departments) VALUES
('SaaS', 'Software as a Service companies', '["Engineering", "Product", "Customer Success", "Data"]'),
('E-commerce', 'Online retail and marketplace platforms', '["Engineering", "Product", "Marketing", "Operations"]'),
('Fintech', 'Financial technology companies', '["Engineering", "Product", "Risk", "Compliance", "Data"]'),
('DevTools', 'Developer tools and infrastructure', '["Engineering", "Product", "Developer Relations", "Data"]'),
('Data Platform', 'Data infrastructure and analytics platforms', '["Engineering", "Data", "Product", "Customer Success"]'),
('Security', 'Cybersecurity and privacy platforms', '["Engineering", "Security", "Product", "Sales"]'),
('EdTech', 'Educational technology platforms', '["Engineering", "Product", "Content", "Data"]'),
('HealthTech', 'Healthcare technology (software focus)', '["Engineering", "Product", "Compliance", "Data"]');

-- Insert departments
INSERT INTO departments (name, description, typical_roles) VALUES
('Engineering', 'Software development and technical infrastructure', 
 '["Backend Engineer", "Frontend Engineer", "DevOps Engineer", "Data Engineer", "ML Engineer", "Security Engineer"]'),
('Product', 'Product management and design', 
 '["Product Manager", "UX Designer", "Product Designer", "Growth PM", "Technical PM"]'),
('Data', 'Data science and analytics', 
 '["Data Scientist", "Analytics Engineer", "BI Developer", "ML Researcher", "Data Analyst"]'),
('Customer Success', 'Customer-facing operations and support', 
 '["Customer Success Manager", "Support Engineer", "Sales Engineer", "Implementation Manager"]'),
('Marketing', 'Growth and customer acquisition', 
 '["Growth Marketer", "Content Manager", "Marketing Analyst", "SEO Specialist"]'),
('Sales', 'Revenue generation and customer acquisition', 
 '["Sales Manager", "Account Executive", "Sales Engineer", "Revenue Operations"]'),
('Operations', 'Business operations and strategy', 
 '["Operations Manager", "Business Analyst", "Strategy Manager", "Finance Manager"]');

-- Insert AI categories
INSERT INTO ai_categories (name, description, technical_complexity, common_use_cases) VALUES
('NLP', 'Natural Language Processing and text analysis', 'Medium', 
 '["Chatbots", "Content Analysis", "Search", "Translation"]'),
('Computer Vision', 'Image and video analysis', 'High', 
 '["Image Recognition", "Quality Control", "Fraud Detection"]'),
('Recommendation Systems', 'Personalization and content recommendation', 'Medium', 
 '["Product Recommendations", "Content Personalization", "Search Ranking"]'),
('Predictive Analytics', 'Forecasting and trend analysis', 'Medium', 
 '["Demand Forecasting", "Churn Prediction", "Risk Assessment"]'),
('Anomaly Detection', 'Identifying unusual patterns', 'Medium', 
 '["Fraud Detection", "System Monitoring", "Quality Control"]'),
('Optimization', 'Resource and process optimization', 'High', 
 '["Route Optimization", "Resource Allocation", "Pricing"]'),
('Classification', 'Categorization and labeling', 'Low', 
 '["Content Moderation", "Lead Scoring", "Ticket Routing"]'),
('Time Series', 'Time-based data analysis', 'Medium', 
 '["Forecasting", "Trend Analysis", "Capacity Planning"]');

-- Insert common business functions
INSERT INTO business_functions (name, category, description, department_id) VALUES
-- Engineering functions
('API Performance Optimization', 'operational', 'Using AI to optimize API response times and reliability', 1),
('Code Quality Assurance', 'operational', 'Automated code review and bug prediction', 1),
('Infrastructure Scaling', 'operational', 'Intelligent auto-scaling based on demand prediction', 1),
('Security Threat Detection', 'operational', 'AI-powered threat detection and response', 1),
('Database Optimization', 'operational', 'Query optimization and performance tuning', 1),

-- Product functions  
('Feature Usage Analysis', 'analytical', 'Understanding which features drive user engagement', 2),
('User Experience Optimization', 'operational', 'A/B testing and personalization', 2),
('Product Roadmap Prioritization', 'strategic', 'Data-driven feature prioritization', 2),
('User Onboarding Optimization', 'operational', 'Personalizing user onboarding flows', 2),

-- Data functions
('Customer Segmentation', 'analytical', 'Grouping customers for targeted strategies', 3),
('Predictive Modeling', 'analytical', 'Building models for business forecasting', 3),
('Data Pipeline Automation', 'operational', 'Automating ETL and data processing', 3),
('Business Intelligence', 'analytical', 'Automated insights and reporting', 3),

-- Customer Success functions
('Churn Risk Assessment', 'analytical', 'Identifying customers at risk of leaving', 4),
('Support Ticket Automation', 'operational', 'Automated ticket routing and responses', 4),
('Customer Health Scoring', 'analytical', 'Measuring customer success and satisfaction', 4),
('Upsell Opportunity Detection', 'analytical', 'Identifying expansion opportunities', 4);

-- Insert initial scraping sources
INSERT INTO scraping_sources (name, base_url, source_type, scraping_config) VALUES
('AWS AI/ML Case Studies', 'https://aws.amazon.com/machine-learning/customers/', 'cloud_provider', 
 '{"target_pages": ["customers"], "company_filter": "technology", "content_sections": ["challenge", "solution", "results"]}'),
('Google Cloud AI Stories', 'https://cloud.google.com/customers/', 'cloud_provider', 
 '{"industry_filter": "technology", "solution_filter": "ai", "extract_fields": ["company", "challenge", "solution", "outcome"]}'),
('Microsoft Azure AI Gallery', 'https://azure.microsoft.com/en-us/solutions/ai/', 'cloud_provider', 
 '{"section": "customer-stories", "tech_focus": true}'),
('Netflix Tech Blog', 'https://netflixtechblog.com/', 'engineering_blog', 
 '{"tags": ["machine-learning", "data-science", "algorithms"], "min_word_count": 1000}'),
('Uber Engineering', 'https://eng.uber.com/', 'engineering_blog', 
 '{"categories": ["ai", "ml", "data"], "extract_code_samples": true}'),
('Airbnb Engineering', 'https://medium.com/airbnb-engineering', 'engineering_blog', 
 '{"topics": ["machine-learning", "data-science"], "include_metrics": true}');

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_use_case_patterns_updated_at BEFORE UPDATE ON use_case_patterns 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scraping_sources_updated_at BEFORE UPDATE ON scraping_sources 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
