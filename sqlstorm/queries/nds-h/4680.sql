WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
CustomerTotal AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierAverageCost AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sac.avg_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierAverageCost sac ON s.s_suppkey = sac.ps_suppkey
    WHERE 
        sac.avg_supply_cost < 100.00
),
CustomerRank AS (
    SELECT
        ct.c_custkey,
        ct.c_name,
        ct.total_spent,
        ROW_NUMBER() OVER (ORDER BY ct.total_spent DESC) as cust_rank
    FROM 
        CustomerTotal ct
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    cr.c_name AS customer_name,
    ts.s_name AS supplier_name,
    ts.avg_supply_cost,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS return_status
FROM 
    RankedOrders r
JOIN 
    CustomerRank cr ON r.o_custkey = cr.c_custkey
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    cr.cust_rank <= 10
    AND (l.l_discount > 0.1 OR l.l_tax IS NULL)
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;