
WITH RegionSales AS (
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
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O') 
        AND l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < (DATE '1998-10-01' - INTERVAL '30 days')
    GROUP BY 
        r.r_name
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    rs.region_name,
    cr.c_name,
    cr.total_spent,
    CASE 
        WHEN cr.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    COALESCE(EXTRACT(YEAR FROM DATE '1998-10-01') - EXTRACT(YEAR FROM o.o_orderdate), 0) AS years_as_customer
FROM 
    RegionSales rs
FULL OUTER JOIN 
    CustomerRanked cr ON rs.region_name IS NOT NULL OR cr.total_spent IS NOT NULL
LEFT JOIN 
    orders o ON cr.c_custkey = o.o_custkey
WHERE 
    (cr.total_spent IS NOT NULL AND rs.total_sales IS NULL) OR 
    (rs.total_sales IS NOT NULL AND cr.total_spent IS NULL)
ORDER BY 
    rs.region_name, cr.total_spent DESC NULLS LAST;
