WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
FilteredCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal < 500
),
JoinResults AS (
    SELECT 
        rc.s_name AS supplier_name,
        fc.c_name AS customer_name,
        fc.nation_name,
        rc.s_acctbal AS supplier_balance,
        fc.c_acctbal AS customer_balance,
        rc.rank
    FROM 
        RankedSuppliers rc
    JOIN 
        FilteredCustomers fc ON rc.nation_name = fc.nation_name
)
SELECT 
    jr.supplier_name,
    jr.customer_name,
    jr.nation_name,
    jr.supplier_balance,
    jr.customer_balance,
    CASE 
        WHEN jr.supplier_balance > jr.customer_balance THEN 'Supplier dominates'
        WHEN jr.supplier_balance < jr.customer_balance THEN 'Customer dominates'
        ELSE 'Equal balance'
    END AS dominance
FROM 
    JoinResults jr
WHERE 
    jr.rank <= 3
ORDER BY 
    jr.nation_name, jr.supplier_balance DESC, jr.customer_balance ASC;
