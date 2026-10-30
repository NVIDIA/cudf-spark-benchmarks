WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ps.total_sales, 0) AS total_sales,
        COALESCE(sc.total_cost, 0) AS total_cost
    FROM 
        part p
    LEFT JOIN 
        PartSales ps ON p.p_partkey = ps.l_partkey
    LEFT JOIN 
        SupplierCost sc ON p.p_partkey = sc.ps_partkey
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.total_sales,
    tp.total_cost,
    CASE 
        WHEN tp.total_sales > 0 THEN (tp.total_cost / tp.total_sales) 
        ELSE NULL 
    END AS cost_to_sales_ratio
FROM 
    TopParts tp
WHERE 
    tp.total_sales IS NOT NULL
ORDER BY 
    cost_to_sales_ratio DESC
LIMIT 10;