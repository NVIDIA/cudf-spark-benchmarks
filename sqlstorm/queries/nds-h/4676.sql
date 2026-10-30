
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderAggregates AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.rnk,
    r.o_orderkey,
    os.total_spent,
    ss.total_supply_cost,
    ss.avg_account_balance
FROM 
    RankedOrders r
LEFT JOIN 
    OrderAggregates os ON r.o_orderkey = os.c_custkey
JOIN 
    SupplierStats ss ON r.o_orderkey = ss.s_suppkey
WHERE 
    (ss.total_supply_cost IS NOT NULL OR os.total_spent IS NOT NULL)
    AND r.o_orderstatus NOT IN ('F', 'O')
ORDER BY 
    r.rnk, os.total_spent DESC
LIMIT 100;
