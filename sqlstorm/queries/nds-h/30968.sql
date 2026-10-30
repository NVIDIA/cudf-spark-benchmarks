WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
BestCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(total_sales) AS total_sales
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_custkey = c.c_custkey
    WHERE 
        s.rn = 1
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RelevantSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        b.total_sales,
        s.part_count,
        s.avg_supplycost
    FROM 
        BestCustomers b
    JOIN 
        customer c ON b.c_custkey = c.c_custkey
    JOIN 
        SupplierStats s ON s.part_count > (SELECT AVG(part_count) FROM SupplierStats)
    WHERE 
        b.total_sales > 10000
)
SELECT 
    r.r_name,
    COALESCE(SUM(rs.total_sales), 0) AS regional_sales,
    COUNT(DISTINCT rs.c_custkey) AS customer_count,
    AVG(rs.avg_supplycost) AS average_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RelevantSales rs ON n.n_nationkey = rs.c_custkey
GROUP BY 
    r.r_name
ORDER BY 
    regional_sales DESC;