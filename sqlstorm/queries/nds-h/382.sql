
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    COALESCE(h.c_name, 'No High Value Customer') AS customer_name,
    s.s_name,
    s.total_supply_cost,
    CASE 
        WHEN r.price_rank = 1 THEN 'Highest Price'
        ELSE 'Other'
    END AS price_category
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueCustomers h ON r.o_orderkey = h.c_custkey
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails s ON l.l_suppkey = s.s_suppkey
WHERE 
    r.price_rank <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
