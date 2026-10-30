WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_acct_balance,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name 
    FROM 
        SupplierSummary s
    WHERE 
        s.rank_within_nation <= 3
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name,
        ci.total_order_value,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY ci.total_order_value DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        CustomerOrders ci ON ci.c_custkey = c.c_custkey
)
SELECT 
    ci.c_custkey,
    ci.c_name,
    ci.region_name,
    ci.total_order_value,
    ci.customer_rank,
    ss.total_supply_cost,
    ss.average_acct_balance
FROM 
    CustomerInfo ci
LEFT JOIN 
    SupplierSummary ss ON ci.total_order_value > ss.total_supply_cost
WHERE 
    ci.customer_rank <= 10
ORDER BY 
    ci.region_name, ci.customer_rank;
