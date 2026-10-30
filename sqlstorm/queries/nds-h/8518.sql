
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationSuppliers AS (
    SELECT 
        n.n_nationkey, 
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        ns.supplier_count AS nation_supplier_count,
        COUNT(DISTINCT co.c_custkey) AS customer_count,
        SUM(rp.total_cost) AS total_parts_cost,
        SUM(co.total_spent) AS total_customer_spent
    FROM 
        region r
    JOIN 
        nation np ON r.r_regionkey = np.n_regionkey
    JOIN 
        NationSuppliers ns ON np.n_nationkey = ns.n_nationkey
    JOIN 
        CustomerOrders co ON np.n_nationkey = co.c_custkey
    JOIN 
        RankedParts rp ON ns.supplier_count > 0
    GROUP BY 
        r.r_name, ns.supplier_count
)
SELECT 
    region_name,
    nation_supplier_count,
    customer_count,
    total_parts_cost,
    total_customer_spent
FROM 
    FinalReport
ORDER BY 
    total_customer_spent DESC, 
    total_parts_cost DESC;
