WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 1000
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    tc.c_name,
    pr.p_name,
    sr.region_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    RankedParts pr ON l.l_partkey = pr.p_partkey AND pr.rank = 1
JOIN 
    TopCustomers tc ON o.o_custkey = tc.c_custkey
JOIN 
    SupplierRegion sr ON l.l_suppkey = sr.s_suppkey
WHERE 
    o.o_orderstatus = 'F'
GROUP BY 
    tc.c_name, pr.p_name, sr.region_name
ORDER BY 
    total_revenue DESC
LIMIT 10;