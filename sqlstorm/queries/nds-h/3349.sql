WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(pd.total_available_quantity, 0) AS available_quantity,
    COALESCE(pd.average_cost, 0) AS average_cost,
    COALESCE(cs.total_orders, 0) AS orders_count,
    COALESCE(cs.total_spent, 0.00) AS total_money_spent,
    cs.purchase_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    PartSupplierDetails pd ON s.s_suppkey = pd.p_partkey
LEFT JOIN 
    CustomerOrderStats cs ON s.s_suppkey = cs.c_custkey
WHERE 
    (pd.total_available_quantity > 100 OR cs.total_orders > 5)
    AND (s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000)
ORDER BY 
    r.r_name, n.n_name, s.s_name;
