
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
), OrderSummary AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_orderkey
    GROUP BY 
        r.r_name, n.n_name
), PartSupplierSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
), CombinedSummary AS (
    SELECT 
        os.region_name,
        os.nation_name,
        os.total_customers,
        os.total_revenue,
        ps.total_available_quantity,
        ps.supplier_count
    FROM 
        OrderSummary os
    FULL OUTER JOIN 
        PartSupplierSummary ps ON os.region_name IS NOT NULL AND ps.supplier_count IS NOT NULL
)
SELECT 
    cs.region_name,
    cs.nation_name,
    COALESCE(cs.total_customers, 0) AS customers,
    COALESCE(cs.total_revenue, 0.00) AS revenue,
    COALESCE(cs.total_available_quantity, 0) AS available_quantity,
    COALESCE(cs.supplier_count, 0) AS suppliers
FROM 
    CombinedSummary cs
WHERE 
    (COALESCE(cs.total_available_quantity, 0) > 100 OR COALESCE(cs.total_revenue, 0.00) > 10000)
ORDER BY 
    cs.region_name, cs.nation_name;
