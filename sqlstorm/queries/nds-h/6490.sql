WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        rs.total_cost,
        rs.supplier_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
)
SELECT 
    cd.c_name AS customer_name,
    cd.total_orders,
    cd.total_spent,
    sd.region_name,
    sd.nation_name,
    sd.supplier_name,
    sd.s_acctbal,
    sd.total_cost,
    sd.supplier_rank
FROM 
    CustomerOrders cd
JOIN 
    SupplierDetails sd ON cd.total_orders > 5 AND sd.supplier_rank = 1
ORDER BY 
    cd.total_spent DESC, sd.total_cost DESC
LIMIT 10;