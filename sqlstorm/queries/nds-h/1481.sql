
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ss.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_supply_cost > 10000
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS revenue_from_returns,
    AVG(CASE 
            WHEN o.o_orderpriority = '1-URGENT' THEN o.o_totalprice 
            ELSE NULL 
        END) AS avg_urgent_order_price,
    s.s_name AS supplier_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerOrderCounts coc ON o.o_custkey = coc.c_custkey
LEFT JOIN 
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_name, p.p_retailprice, s.s_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 AND
    AVG(o.o_totalprice) IS NOT NULL
ORDER BY 
    revenue_from_returns DESC, customer_count DESC;
