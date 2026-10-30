WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_phone,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank_supplier
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    r.r_name AS region_name,
    cs.total_spent,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_line_item_value,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails s ON ps.ps_partkey = s.ps_partkey AND s.rank_supplier = 1
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
LEFT JOIN 
    RankedOrders o ON li.l_orderkey = o.o_orderkey AND o.rank_order <= 10
LEFT JOIN 
    CustomerSales cs ON n.n_nationkey = cs.c_custkey
WHERE 
    p.p_retailprice < 50.00
GROUP BY 
    p.p_partkey, p.p_name, supplier_name, r.r_name, cs.total_spent
ORDER BY 
    total_line_item_value DESC 
LIMIT 100;
