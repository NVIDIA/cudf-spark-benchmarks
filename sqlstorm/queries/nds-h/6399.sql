WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1998-01-01' 
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.nation_name,
        ROW_NUMBER() OVER (PARTITION BY s.nation_name ORDER BY s.total_sales DESC) AS rank
    FROM 
        SupplierSales s
)
SELECT 
    r.nation_name,
    r.s_suppkey,
    r.s_name,
    r.total_sales
FROM 
    RankedSales r
WHERE 
    r.rank <= 5
ORDER BY 
    r.nation_name, r.total_sales DESC;