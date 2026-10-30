WITH  TotalSales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_price
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT 
        ts.c_custkey,
        ts.c_name,
        ts.total_price,
        ROW_NUMBER() OVER (ORDER BY ts.total_price DESC) AS sales_rank
    FROM 
        TotalSales ts
),
SuppliersWithParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        SUM(ps.ps_availqty) as total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_container LIKE 'SM%'
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
SupplierStats AS (
    SELECT
        swp.s_suppkey,
        swp.s_name,
        AVG(swp.total_avail_qty) AS avg_avail_qty
    FROM 
        SuppliersWithParts swp
    GROUP BY 
        swp.s_suppkey, swp.s_name
)
SELECT 
    rs.c_name,
    rs.total_price,
    ss.s_name,
    ss.avg_avail_qty
FROM 
    RankedSales rs
LEFT JOIN 
    SupplierStats ss ON rs.sales_rank <= 10 AND rs.c_custkey % ss.s_suppkey = 0
WHERE 
    rs.total_price IS NOT NULL
ORDER BY 
    rs.total_price DESC, 
    ss.avg_avail_qty DESC
LIMIT 50;
