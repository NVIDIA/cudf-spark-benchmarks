
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
FilteredPartCounts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 0
)
SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(FilteredPartCounts.supplier_count, 0)) AS total_suppliers,
    AVG(CustomerOrders.total_spent) AS avg_spent_per_customer,
    COUNT(DISTINCT RankedOrders.o_orderkey) AS total_orders,
    MAX(RankedOrders.o_orderdate) AS latest_order_date
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    FilteredPartCounts ON ps.ps_partkey = FilteredPartCounts.p_partkey
LEFT JOIN 
    CustomerOrders ON s.s_nationkey = CustomerOrders.c_nationkey
LEFT JOIN 
    RankedOrders ON RankedOrders.o_orderkey = ps.ps_partkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    AVG(CustomerOrders.total_spent) > 1000
ORDER BY 
    total_suppliers DESC, avg_spent_per_customer DESC;
