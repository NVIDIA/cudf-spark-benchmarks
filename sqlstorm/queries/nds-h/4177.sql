
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerTotals AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ct.total_spent
    FROM 
        customer c
    JOIN 
        CustomerTotals ct ON c.c_custkey = ct.c_custkey
    WHERE 
        ct.total_spent > 10000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    s.s_name,
    p.p_name,
    COALESCE(sp.total_avail_qty, 0) AS available_quantity,
    COALESCE(sp.avg_supply_cost, 0) AS average_supply_cost,
    ctc.total_spent
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighSpendingCustomers ctc ON ctc.c_custkey = r.o_orderkey
WHERE 
    r.rank <= 5
    AND r.o_orderstatus = 'F'
ORDER BY 
    r.o_totalprice DESC, ctc.total_spent DESC;
