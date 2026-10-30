
WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
RecentOrders AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        SUM(cust.o_totalprice) AS total_spent,
        COUNT(cust.o_orderkey) AS order_count
    FROM 
        CustomerOrders cust
    WHERE 
        cust.order_rank <= 5
    GROUP BY 
        cust.c_custkey, cust.c_name
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
CombinedData AS (
    SELECT 
        r.r_name,
        RANK() OVER (ORDER BY SUM(so.total_spent) DESC) AS region_rank,
        SUM(so.total_spent) AS total_spent_by_region,
        ns.total_balance
    FROM 
        RecentOrders so
    LEFT JOIN 
        customer c ON so.c_custkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        NationSupplier ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY 
        r.r_name, ns.total_balance
)
SELECT 
    cb.r_name,
    cb.total_spent_by_region,
    cb.region_rank,
    CASE 
        WHEN cb.total_balance IS NULL THEN 'No Balance'
        ELSE CAST(cb.total_balance AS STRING)
    END AS supplier_balance
FROM 
    CombinedData cb
WHERE 
    cb.total_spent_by_region > (SELECT AVG(total_spent_by_region) FROM CombinedData)
ORDER BY 
    cb.region_rank;
