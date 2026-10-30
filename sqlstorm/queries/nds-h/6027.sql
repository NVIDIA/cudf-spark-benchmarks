WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT * 
    FROM RankedOrders 
    WHERE revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    SUM(l.l_extendedprice * l.l_discount) AS total_discounted_amount
FROM 
    TopRevenueOrders tro
JOIN 
    orders o ON tro.o_orderkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    o.o_orderkey, o.o_orderstatus
ORDER BY 
    total_extended_price DESC;
