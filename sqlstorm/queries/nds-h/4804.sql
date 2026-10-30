
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > 10000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_orderstatus,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    cu.c_name AS customer_name,
    cu.total_spent,
    r.order_rank
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN 
    HighValueCustomers cu ON cu.c_custkey IN (SELECT o.o_custkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.o_orderstatus = 'O'
    AND ss.total_supply_cost IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, 
    r.o_orderkey;
