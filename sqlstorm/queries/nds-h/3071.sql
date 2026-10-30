
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        c.c_custkey, c.c_name
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        TopCustomers c
)
SELECT 
    rs.region_name,
    cr.c_name,
    cr.total_spent,
    COALESCE(rs.total_sales, 0) AS region_sales,
    (SELECT AVG(ps.ps_availqty) FROM partsupp ps) AS avg_avail_qty
FROM 
    RegionalSales rs
FULL OUTER JOIN 
    CustomerRanked cr ON rs.region_name IS NOT NULL
WHERE 
    cr.rank <= 10 OR cr.rank IS NULL
ORDER BY 
    rs.region_name, cr.total_spent DESC;
