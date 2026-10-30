WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 50
)
SELECT 
    rs.p_partkey,
    rs.p_name,
    rs.total_sales,
    sa.total_avail_qty,
    tn.n_name AS key_nation
FROM 
    RankedSales rs
LEFT JOIN 
    SupplierAvailability sa ON rs.p_partkey = sa.ps_partkey
JOIN 
    partsupp ps ON rs.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopNations tn ON s.s_nationkey = tn.n_nationkey
WHERE 
    rs.rank <= 10 
    AND rs.total_sales > 1000 
    AND (sa.total_avail_qty IS NULL OR sa.total_avail_qty > 500)
ORDER BY 
    rs.total_sales DESC;
