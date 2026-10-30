
WITH  RegionalSales AS (
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
SalesRank AS (
    SELECT 
        rs.region_name,
        rs.total_sales,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RegionalSales rs
),
NullCheck AS (
    SELECT 
        sr.region_name,
        sr.total_sales,
        sr.sales_rank,
        CASE 
            WHEN sr.sales_rank IS NULL THEN 'No Sales'
            ELSE 'Has Sales'
        END AS sales_status
    FROM 
        SalesRank sr
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(nc.region_name, 'Unknown Region') AS region_name,
    COALESCE(nc.total_sales, 0) AS total_sales,
    nc.sales_status
FROM 
    nation n
LEFT JOIN 
    NullCheck nc ON n.n_nationkey = (
        SELECT 
            s.s_nationkey
        FROM 
            supplier s
        WHERE 
            s.s_suppkey IN (
                SELECT 
                    ps.ps_suppkey 
                FROM 
                    partsupp ps
                WHERE 
                    ps.ps_partkey IN (
                        SELECT 
                            p.p_partkey 
                        FROM 
                            part p
                        WHERE 
                            p.p_size > 20
                    )
            )
        LIMIT 1
    )
ORDER BY 
    n.n_name;
