WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(s.unique_suppliers, 0) AS unique_suppliers,
    t.c_name AS top_customer_name,
    t.total_spent
FROM 
    part p
LEFT JOIN 
    SupplierPartDetails s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    TopCustomers t ON t.total_spent = (SELECT MAX(total_spent) FROM TopCustomers)
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND NOT EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_shipdate < DATE '1997-01-01'
    )
ORDER BY 
    p.p_partkey;