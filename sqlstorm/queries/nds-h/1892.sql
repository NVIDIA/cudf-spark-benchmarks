WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
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
NationProfile AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(COALESCE(sd.num_parts, 0)) AS total_supplier_parts,
        SUM(COALESCE(co.total_spent, 0)) AS total_customer_spending
    FROM 
        nation n
    LEFT JOIN 
        SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    LEFT JOIN 
        CustomerOrders co ON n.n_nationkey = co.c_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    np.n_name,
    np.total_supplier_parts,
    np.total_customer_spending,
    ABS(np.total_supplier_parts - np.total_customer_spending) AS supply_customer_diff,
    ROW_NUMBER() OVER (ORDER BY np.total_customer_spending DESC) AS rank
FROM 
    NationProfile np
WHERE 
    np.total_customer_spending IS NOT NULL
ORDER BY 
    supply_customer_diff DESC
LIMIT 10;
