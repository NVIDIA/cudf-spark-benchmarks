
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND 
        EXTRACT(MONTH FROM o.o_orderdate) BETWEEN 1 AND 6
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(l.l_discount) AS max_discount,
        MIN(l.l_tax) AS min_tax
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate > DATE '1998-10-01' - INTERVAL '90 days'
    GROUP BY 
        s.s_suppkey
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
    WHERE 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    MAX(ss.total_cost) AS max_supplier_cost,
    SUM(ss.order_count) FILTER (WHERE ss.order_count > 0) AS total_valid_orders,
    COUNT(DISTINCT so.o_orderkey) AS unique_placed_orders,
    RANK() OVER (ORDER BY MAX(ss.total_cost) DESC) AS rank_by_cost
FROM 
    SupplierSales ss
FULL OUTER JOIN 
    CustomerInfo c ON ss.s_suppkey = c.c_custkey
LEFT JOIN 
    RankedOrders so ON so.o_orderkey = ss.s_suppkey
WHERE 
    (ss.total_cost IS NOT NULL OR c.c_custkey IS NULL)
    AND (ss.max_discount < 0.15 OR ss.min_tax IS NULL)
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    MAX(ss.total_cost) > (SELECT AVG(total_cost) FROM SupplierSales)
ORDER BY 
    rank_by_cost
LIMIT 10 OFFSET 5;
