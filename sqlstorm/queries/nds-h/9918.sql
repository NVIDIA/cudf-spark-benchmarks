WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ts.total_sales
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    WHERE 
        p.p_retailprice > 100.00
)
SELECT 
    rp.r_name,
    COUNT(DISTINCT tp.p_partkey) AS number_of_parts,
    SUM(tp.total_sales) AS total_sales_value
FROM 
    region rp
JOIN 
    nation n ON rp.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    TopParts tp ON ps.ps_partkey = tp.p_partkey
GROUP BY 
    rp.r_name
ORDER BY 
    total_sales_value DESC;