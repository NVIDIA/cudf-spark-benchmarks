
WITH SupplierTotalCost AS (
    SELECT 
        ps_suppkey,
        SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM 
        partsupp
    GROUP BY 
        ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer AS c
    JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation AS n
    LEFT JOIN 
        supplier AS s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer AS c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.customer_count,
    COALESCE(ct.total_spent, 0) AS total_customer_spent,
    st.total_cost,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY ns.supplier_count DESC) AS rank_by_supplier
FROM 
    NationStats AS ns
JOIN 
    SupplierTotalCost AS st ON ns.supplier_count > 0
LEFT JOIN 
    CustomerOrders AS ct ON ns.n_nationkey = ct.c_custkey
ORDER BY 
    ns.n_name, rank_by_supplier;
