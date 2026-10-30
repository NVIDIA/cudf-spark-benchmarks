WITH  SalesData AS (
    SELECT 
        n.n_name AS nation_name,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
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
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '1996-01-01' AND 
        l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
RankedSales AS (
    SELECT 
        nation_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SalesData
)
SELECT 
    nation_name,
    total_sales,
    order_count,
    rank
FROM 
    RankedSales
WHERE 
    rank <= 10
ORDER BY 
    rank;