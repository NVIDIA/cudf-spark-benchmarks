
WITH  SupplyChain AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_availqty) AS total_availqty 
    FROM 
        partsupp 
    GROUP BY 
        ps_partkey, ps_suppkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT 
                AVG(o2.o_totalprice) 
            FROM 
                orders o2 
            WHERE 
                o2.o_orderdate >= DATE '1997-01-01'
        )
),
SupplierStats AS (
    SELECT 
        s.s_nationkey, 
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    COALESCE(SUM(sc.total_availqty), 0) AS total_available_supply,
    ss.unique_suppliers,
    ss.avg_balance
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    SupplyChain sc ON sc.ps_partkey = l.l_partkey
JOIN 
    SupplierStats ss ON ss.s_nationkey = n.n_nationkey
WHERE 
    r.r_name LIKE 'A%'
    AND (l.l_shipdate IS NOT NULL OR l.l_returnflag = 'R')
GROUP BY 
    r.r_name, n.n_name, ss.unique_suppliers, ss.avg_balance
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 100000
ORDER BY 
    total_sales DESC, n.n_name;
