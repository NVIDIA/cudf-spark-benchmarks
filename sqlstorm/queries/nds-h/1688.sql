
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
),
TotalOrders AS (
    SELECT 
        cs.c_name,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        CustomerSummary cs
    JOIN 
        lineitem l ON cs.c_custkey = l.l_orderkey
    GROUP BY 
        cs.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    cs.c_name,
    cs.total_spent,
    COALESCE(ss.total_supply_cost, 0) AS supply_cost,
    t.total_lineitems
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerSummary cs ON r.o_orderkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON r.o_orderkey = ss.ps_partkey
JOIN 
    TotalOrders t ON cs.c_name = t.c_name
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, 
    cs.total_spent DESC;
