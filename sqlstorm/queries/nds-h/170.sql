WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty < 20
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    tc.c_name,
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    COALESCE(sp.ps_supplycost * r.o_totalprice / NULLIF(sp.ps_availqty, 0), 0) AS cost_ratio
FROM 
    RankedOrders r
LEFT JOIN 
    TopCustomers tc ON r.o_orderkey = tc.c_custkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_availqty IN (SELECT DISTINCT ps.ps_availqty FROM SupplierParts ps)
WHERE 
    r.rank <= 5
ORDER BY 
    r.o_orderdate DESC, 
    cost_ratio DESC;