
WITH region_summary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
cost_analysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    rs.r_name,
    rs.total_nations,
    rs.total_supplier_balance,
    tc.c_name AS top_customer,
    tc.total_spent,
    ca.p_name AS popular_part,
    ca.total_cost
FROM 
    region_summary rs
FULL OUTER JOIN 
    top_customers tc ON rs.total_nations > 10
LEFT JOIN 
    (SELECT 
         p.p_name,
         ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS part_rank
     FROM 
         part p 
     JOIN 
         partsupp ps ON p.p_partkey = ps.ps_partkey
     GROUP BY 
         p.p_name) popular_parts ON popular_parts.part_rank = 1
LEFT JOIN 
    cost_analysis ca ON popular_parts.p_name = ca.p_name
WHERE 
    rs.total_supplier_balance IS NOT NULL 
    OR tc.total_spent IS NOT NULL;
